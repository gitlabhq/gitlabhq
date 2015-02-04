module Gitlab
  class GitAccessStatus
    attr_accessor :status, :message
    alias_method :allowed?, :status

    def initialize(status, message = '')
      @status = status
      @message = message
    end

    def to_json
      { status: @status, message: @message }.to_json
    end
  end
end
