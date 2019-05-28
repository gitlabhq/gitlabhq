run lambda { |env| [200, { 'Content-Type' => 'text/plain' }, StringIO.new("Hello World! #{ENV['OPTIONAL_MESSAGE']}\n")] }
