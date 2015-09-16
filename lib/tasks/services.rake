services_template = <<-ERB
# Services

<% services.each do |service| %>
## <%= service[:title] %>


<% unless service[:description].blank? %>
<%= service[:description] %>
<% end %>


### Create/Edit <%= service[:title] %> service

Set <%= service[:title] %> service for a project.
<% unless service[:help].blank? %>

> <%= service[:help].gsub("\n", ' ') %>

<% end %>

```
PUT /projects/:id/services/<%= service[:dashed_name] %>

```

Parameters:

<% service[:params].each do |param| %>
- `<%= param[:name] %>` <%= param[:required] ? "(**required**)" : "(optional)"  %><%= [" -",  param[:description]].join(" ").gsub("\n", '') unless param[:description].blank? %>

<% end %>

### Delete <%= service[:title] %> service

Delete <%= service[:title] %> service for a project.

```
DELETE /projects/:id/services/<%= service[:dashed_name] %>

```

### Get <%= service[:title] %> service settings

Get <%= service[:title] %> service settings for a project.

```
GET /projects/:id/services/<%= service[:dashed_name] %>

```

<% end %>
ERB

namespace :services do
  task doc: :environment do
    services = Service.available_services_names.map do |s|
      service_start = Time.now
      klass = "#{s}_service".classify.constantize

      service = klass.new

      service_hash = {}

      service_hash[:title] = service.title
      service_hash[:dashed_name] = s.dasherize
      service_hash[:description] = service.description
      service_hash[:help] = service.help
      service_hash[:params] = service.fields.map do |p|
        param_hash = {}

        param_hash[:name] = p[:name]
        param_hash[:description] = p[:placeholder] || p[:title]
        param_hash[:required] = klass.validators_on(p[:name].to_sym).any? do |v|
          v.class == ActiveRecord::Validations::PresenceValidator
        end

        param_hash
      end.sort_by { |p| p[:required] ? 0 : 1 }

      puts "Collected data for: #{service.title}, #{Time.now-service_start}"
      service_hash
    end

    doc_start = Time.now
    doc_path = File.join(Rails.root, 'doc', 'api', 'services.md')

    result = ERB.new(services_template, 0 , '>')
      .result(OpenStruct.new(services: services).instance_eval { binding })

    File.open(doc_path, 'w') do |f|
      f.write result
    end

    puts "write a new service.md to: #{doc_path.to_s}, #{Time.now-doc_start}"

  end
end
