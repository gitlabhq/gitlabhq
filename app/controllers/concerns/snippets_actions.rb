module SnippetsActions
  extend ActiveSupport::Concern

  def edit
  end

  def raw
    send_data(
      convert_line_endings(@snippet.content),
      type: 'text/plain; charset=utf-8',
      disposition: 'inline',
      filename: @snippet.sanitized_file_name
    )
  end

  private

  def convert_line_endings(content)
    params[:line_ending] == 'raw' ? content : content.gsub(/\r\n/, "\n")
  end
end
