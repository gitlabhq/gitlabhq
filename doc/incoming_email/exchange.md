# Set up Exchange for Reply by email

This document will take you through the steps for configure exchange to be used with Reply by email.

The instructions make the assumption that you already have a working Exchange server.

## 1. Add Gitlab mailbox

1. Got to Exchange ECP
2. Add a new mailbox (and user) for GitLab with the password you want

## 2. Install RegExCatchAllAgent

For supporting plus-subaddressing (email likes `<alias>+{random_string}@domain.com` will be redirected to `<alias>@domain.com`), you have to install a custom agent.

The agent we will install was created by http://durdle.com/regexcatchall/.

If you have Exchange 2013 CU 10 or Exchange 2016 you can use [this precompiled dll](https://github.com/pupaxxo/RegExCatchAllAgent/releases), else you have to build by yourself using your own installed instance dlls ([Go here for more info](#Compile_agent_for_your_version_18))

1. Download dlls
2. Right click downloaded dll and check if the file has the "Internet Lock" (windows automatically add it when you download dll from internet), if yes remove it (this is important!)
3. Move dll to a new directory like C:/CatchAllAgent/
4. Open Exchange Management Shell
5. `Install-TransportAgent -Name "RegExCatchAll Agent" -TransportAgentFactory:RegExCatchAllAgent.CatchAllFactory -AssemblyPath:"<path>"` (Replace path with the dll path)
6. Run `Get-TransportAgent` and check if the new installed agent is BEFORE the `Recipient Filter Agent` (if don't have the filter agent you could skip this step, just be sure that the new agent isn't after a filter agent), if yes `Set-TransportAgent "RegExCatchAll Agent" -Priority:<RecipientFilterAgentPriority>`
7. `Enable-TransportAgent "RegExCatchAll Agent"`
8. Restart services `net stop MSExchangeTransport` and `net start MSExchangeTransport`

# 3. Setup IMAP

1. Open `services.msc`
2. Search `Microsoft Exchange IMAP4` and set it to start automatically, then start it
3. Search `Microsoft Exchange IMAP4 Backend` and set it to start automatically, then start it
4. Open ECP, and go to server settings
5. Go to IMAP settings
6. Change `MIME Type` to `HTML with alternative text`
7. Restart step 2 and 3 services

# 4. Setup Firewall
Open port 993 on your exchange server, this is the only port needed! (and port 25 if you also use exchange for sending mails)

# 5. Configure GitLab

1. Edit gitlab.yml
2. Use port `993`, host `<exchange fqdn>`, ssl `true`, starttls `false`, username `<Domain>\\GitLab`, and password is the password you have set when you have created the mailbox
3. Restart gitlab and check mailrom.log if ther'are any errors

## 6. Done!

Run tests `sudo -u git -H bundle exec rake gitlab:incoming_email:check RAILS_ENV=production` and check if all is ok, if so Reply by Mail should be working!

## Compile agent for your version
1. Download Visual Studio (if you don't already have it)
2. Import projects from https://github.com/pupaxxo/RegExCatchAllAgent
3. Change dll using the ones you find in `C:\Program Files\Microsoft\Exchange Server\V<VersionNumber>\Public`
4. Compile