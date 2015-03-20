path = File.expand_path("~/.ssh/bitbucket_isa.pub")
Gitlab::BitbucketImport.public_key = File.read(path) if File.exist?(path)
