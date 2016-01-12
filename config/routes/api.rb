API::API.logger Rails.logger
mount API::API => '/'
mount GrapeSwaggerRails::Engine => '/apidoc'
