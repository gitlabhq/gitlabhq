---
stage: none
group: unassigned
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
---

# Components

## Graphs

We have a lot of graphing libraries in our codebase to render graphs. In an effort to improve maintainability, new graphs should use [D3.js](https://d3js.org/). If a new graph is fairly simple, consider implementing it in SVGs or HTML5 canvas.

We chose D3 as our library going forward because of the following features:

- [Tree shaking webpack capabilities](https://github.com/d3/d3/blob/master/CHANGES.md#changes-in-d3-40).
- [Compatible with vue.js as well as vanilla JavaScript](https://github.com/d3/d3/blob/master/CHANGES.md#changes-in-d3-40).

D3 is very popular across many projects outside of GitLab:

- [The New York Times](https://archive.nytimes.com/www.nytimes.com/interactive/2012/02/13/us/politics/2013-budget-proposal-graphic.html)
- [plot.ly](https://plotly.com/)
- [Ayoa](https://www.ayoa.com/previously-droptask/)

Within GitLab, D3 has been used for the following notable features

- [Prometheus graphs](../../../user/project/integrations/prometheus.md)
- Contribution calendars
