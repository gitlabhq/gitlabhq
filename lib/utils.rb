module Utils
  module FileHelper
    def binary?(string)
      string.each_byte do |x|
        x.nonzero? or return true
      end
      false
    end

    def image?
      mime_type =~ /image/
    end

    def text?
      mime_type =~ /application|text/ && !binary?(data)
    end
  end

  module Colorize
    def colorize
      system_colorize(data, name)
    end

    def system_colorize(data, file_name)
      options = { :encoding => 'utf-8', :linenos => 'True' }

      # Try detect language with pygments
      Pygments.highlight data, :filename => file_name, :options => options
    rescue 
      # if it fails use manual detection
      ft = handle_file_type(file_name)
      Pygments.highlight(data, :lexer => ft, :options => options)
    end

    def handle_file_type(file_name)
      case file_name
      when /(\.ru|Gemfile)$/
        :ruby
      else
        :text
      end
    end
  end
end
