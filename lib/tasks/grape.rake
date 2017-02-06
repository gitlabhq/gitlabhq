namespace :grape do
  desc 'Print compiled grape routes'
  task routes: :environment do
    API::API.routes.each do |route|
      puts "#{route.options[:method]} #{route.path} - #{route_description(route.options)}"
    end
  end

  def route_description(options)
    if options[:settings][:description]
      options[:settings][:description][:description]
    end || ''
  end
end
