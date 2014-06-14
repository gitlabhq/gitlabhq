class HelpController < ApplicationController
  def index
  end

  def show
    @category = params[:category]
    @file = params[:file]

    if File.exists?(Rails.root.join('doc', @category, @file + '.md'))
      render 'show'
    else
      not_found!
    end
  end

  def shortcuts
  end
end
