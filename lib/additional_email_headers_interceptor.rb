class AdditionalEmailHeadersInterceptor
  def self.delivering_email(message)
    message.headers(
      'Auto-Submitted' => 'auto-generated',
      'X-Auto-Response-Suppress' => 'All'
    )
  end
end
