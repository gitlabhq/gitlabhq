# Request Profiling

## Procedure
1. Grab the profiling token from `Monitoring > Requests Profiles` admin page
(highlighted in a blue in the image below).
![Profile token](img/request_profiling_token.png)
1. Pass the header `X-Profile-Token: <token>` to the request you want to profile. You can use any of these tools
    * [ModHeader](https://chrome.google.com/webstore/detail/modheader/idgpnmonknjnojddfkpgkljpfnnfcklj) Chrome extension
    * [Modify Headers](https://addons.mozilla.org/en-US/firefox/addon/modify-headers/) Firefox extension
    * `curl --header 'X-Profile-Token: <token>' https://gitlab.example.com/group/project`
1. Once request is finished (which will take a little longer than usual), you can
view the profiling output from `Monitoring > Requests Profiles` admin page.
![Profiling output](img/request_profile_result.png)

## Cleaning up
Profiling output will be cleared out every day via a Sidekiq worker.
