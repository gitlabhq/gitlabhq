class Admin::EmailsController < Admin::ApplicationController
  def index
    render text: 'hello world', layout: nil
  end
end
