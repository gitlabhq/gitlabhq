class AdditionalEmailHeadersInterceptor
  def self.delivering_email(message)
    message.header['Auto-Submitted'] ||= 'auto-generated'
    message.header['X-Auto-Response-Suppress'] ||= 'All'
  end
end
