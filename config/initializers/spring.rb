if Rails.env.development? || Rails.env.test?
  Thread.abort_on_exception = false
  Thread.send(:define_method, :abort_on_exception) do |value|
    puts "Ignoring Thread.abort_on_exception change to #{value}"
  end
end
