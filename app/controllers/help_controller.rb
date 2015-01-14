class HelpController < ApplicationController
  def index
  end

  def show
    @category = params[:category]
    @file = params[:file]
    format = params[:format] || 'md'
    file_path = Rails.root.join('doc', @category, @file + ".#{format}")

    if %w(png jpg jpeg gif).include?(format)
      send_file file_path, disposition: 'inline'
    elsif File.exists?(file_path)
      render 'show'
    else
      not_found!
    end
  end

  def shortcuts
  end
end
