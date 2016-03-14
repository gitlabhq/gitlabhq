# Webhooks and insecure internal web services

If you have non-GitLab web services running on your GitLab server or within its local network, these may be vulnerable to exploitation via Webhooks.

With [Webhooks](../web_hooks/web_hooks.md), you and your project masters and owners can set up URLs to be triggered when specific things happen to projects. Normally, these requests are sent to external web services specifically set up for this purpose, that process the request and its attached data in some appropriate way. 

Things get hairy, however, when a Webhook is set up with a URL that doesn't point to an external, but to an internal service, that may do something completely unintended when the webhook is triggered and the POST request is sent.

Because Webhook requests are made by the GitLab server itself, these have complete access to everything running on the server (http://localhost:123) or within the server's local network (http://192.168.1.12:345), even if these services are otherwise protected and inaccessible from the outside world.

If a web service does not require authentication, Webhooks can be used to trigger destructive commands by getting the GitLab server to make POST requests to endpoints like "http://localhost:123/some-resource/delete". 

To prevent this type of exploitation from happening, make sure that you are aware of every web service GitLab could potentially have access to, and that all of these are set up to require authentication for every potentially destructive command. Enabling authentication but leaving a default password is not enough.