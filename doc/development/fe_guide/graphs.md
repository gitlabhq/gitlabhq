# Graphs

GitLab currently uses multiple graphics libraries to render all the graphs, as part of our efforts to help with the maintainability of the frontend code, the only library that will be used from this point onward, will be `d3.js`

`d3.js` has been battle tested on big features such as our prometheus graphs and contribution calendars. Also it gives us a couple of cool features such as:

* Tree shaking webpack capabilities.
* Compatible with vue.js as well as vanilla javascript.

Of course there will be instances where creating graphs manually using SVG or canvas HTML 5 graphics will be totally doable, if that's case just make sure to not add more libraries to maintain.
