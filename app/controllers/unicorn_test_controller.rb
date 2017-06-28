if Rails.env.test?
  class UnicornTestController < ActionController::Base
    def pid
      render plain: Process.pid.to_s
    end
  
    def kill
      Process.kill(params[:signal], Process.pid)
      render plain: 'Bye!'
    end
  end
end
