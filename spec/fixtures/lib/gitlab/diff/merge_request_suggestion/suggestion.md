```suggestion:-6+1

get '/file/:filename' do
  sanitized_filename = File.basename(params['filename'].to_s)
  file_path = File.expand_path(File.join("./files", sanitized_filename))
  base_path = File.expand_path("./files")

  if File.exist?(file_path) && file_path.start_with?(base_path)
    send_file(file_path, disposition: 'attachment', filename: sanitized_filename)
  else
    halt 404, "File not found"
```