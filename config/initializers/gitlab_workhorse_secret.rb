begin
  Gitlab::Workhorse.secret
rescue
  Gitlab::Workhorse.write_secret
end

# Try a second time. If it does not work this will raise.
Gitlab::Workhorse.secret
