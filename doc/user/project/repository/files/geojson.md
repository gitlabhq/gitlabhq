---
stage: Create
group: Source Code
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
description: "How GeoJSON files are rendered when viewed in GitLab projects."
title: GeoJSON files
---

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab.com, GitLab Self-Managed, GitLab Dedicated

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/14134) in GitLab 16.1.

A GeoJSON file is a format for encoding geographical data structures using JavaScript Object Notation (JSON).
It is commonly used for representing geographic features, such as points, lines, and polygons, along with their associated attributes.

When added to a repository, files with a `.geojson` extension are rendered as a map containing the GeoJSON data when viewed in GitLab.

Map data comes from [OpenStreetMap](https://www.openstreetmap.org/) under the [Open Database License](https://www.openstreetmap.org/copyright).

![GeoJSON file rendered as a map](img/geo_json_file_rendered_v16_1.png)
