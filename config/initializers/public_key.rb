path = File.expand_path("~/.ssh/bitbucket_rsa.pub")
Gitlab::BitbucketImport.public_key = File.read(path) if File.exist?(path)
