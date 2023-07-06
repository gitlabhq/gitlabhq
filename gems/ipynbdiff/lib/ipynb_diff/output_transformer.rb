# frozen_string_literal: true

require 'ipynb_diff/symbolized_markdown_helper'

module IpynbDiff
  # Transforms Jupyter output data into markdown
  class OutputTransformer
    include SymbolizedMarkdownHelper

    HIDDEN_IMAGE_OUTPUT = '    [Hidden Image Output]'

    ORDERED_KEYS = {
      'execute_result' => %w[image/png image/svg+xml image/jpeg text/markdown text/latex text/plain],
      'display_data' => %w[image/png image/svg+xml image/jpeg text/markdown text/latex],
      'stream' => %w[text]
    }.freeze

    def initialize(hide_images = false)
      @hide_images = hide_images
    end

    def transform(output, symbol)
      case (output_type = output['output_type'])
      when 'error'
        transform_error(output['traceback'], symbol / 'traceback')
      when 'execute_result', 'display_data'
        transform_non_error(ORDERED_KEYS[output_type], output['data'], symbol / 'data')
      when 'stream'
        transform_element('text', output['text'], symbol)
      end
    end

    def transform_error(traceback, symbol)
      traceback.map.with_index do |t, idx|
        t.split("\n").map do |l|
          ___(symbol / idx, l.gsub(/\[[0-9][0-9;]*m/, '').sub("\u001B", '    ').delete("\u001B").rstrip)
        end
      end
    end

    def transform_non_error(accepted_keys, elements, symbol)
      accepted_keys.filter { |key| elements.key?(key) }.map do |key|
        transform_element(key, elements[key], symbol)
      end
    end

    def transform_element(output_type, output_element, symbol_prefix)
      new_symbol = symbol_prefix / output_type
      case output_type
      when 'image/png', 'image/jpeg'
        transform_image("#{output_type};base64", output_element, new_symbol)
      when 'image/svg+xml'
        transform_image("#{output_type};utf8", output_element, new_symbol)
      when 'text/markdown', 'text/latex', 'text/plain', 'text'
        transform_text(output_element, new_symbol)
      end
    end

    def transform_image(image_type, image_content, symbol)
      return ___(nil, HIDDEN_IMAGE_OUTPUT) if @hide_images

      lines = image_content.is_a?(Array) ? image_content : [image_content]

      single_line = lines.map(&:strip).join.gsub(/\s+/, ' ')

      ___(symbol, "    ![](data:#{image_type},#{single_line})")
    end

    def transform_text(text_content, symbol)
      symbolize_array(symbol, text_content) { |l| "    #{l.rstrip}" }
    end
  end
end
