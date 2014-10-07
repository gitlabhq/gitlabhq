class HelpController < ApplicationController
  def index
  end

  def show
    @filepath = params[:filepath]
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
end
