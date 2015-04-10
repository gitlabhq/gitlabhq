class HelpController < ApplicationController
  def index
  end

  def show
    @filepath = clean_path_info(params[:filepath])
    @format = params[:format]

    respond_to do |format|
      format.md { render_doc }
      format.all { send_file_data }
    end
  end

  def shortcuts
  end

  private

  def render_doc
    if File.exists?(Rails.root.join('doc', @filepath + '.md'))
      render 'show.html.haml'
    else
      not_found!
    end
  end

  def send_file_data
    path = Rails.root.join('doc', "#{@filepath}.#{@format}")
    if File.exists?(path)
      send_file(path, disposition: 'inline')
    else
      head :not_found
    end
  end

  def ui
  end

  # Taken from ActionDispatch::FileHandler
  PATH_SEPS = Regexp.union(*[::File::SEPARATOR, ::File::ALT_SEPARATOR].compact)

  def clean_path_info(path_info)
    parts = path_info.split PATH_SEPS

    clean = []

    parts.each do |part|
      next if part.empty? || part == '.'
      part == '..' ? clean.pop : clean << part
    end

    clean.unshift '/' if parts.empty? || parts.first.empty?

    ::File.join(*clean)
  end
end
