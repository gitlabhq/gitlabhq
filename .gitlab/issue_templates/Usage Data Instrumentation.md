<!-- Guide for product managers or engineering teams looking to track usage of their features -->

:warning: If GDK is accessible, an alternative to using this guide is to directly establish event/metric definitions using our [internal events generator](https://docs.gitlab.com/ee/development/internal_analytics/internal_event_instrumentation/quick_start.html#defining-event-and-metrics)

## Objective

<!-- The primary goal or purpose behind instrumenting this feature or project. What insights are we aiming to gather? 

Examples: 
Feature adoption and engagement
- How many unique users/projects/namespaces engage with the feature?
- Frequency with which users return to specific features over time?

User Flow and Navigation
- Sequences of actions users take within the product or feature
- Specific user actions or behaviors tracked as events -->


## Events and Metrics

[Definition of events and metrics](https://docs.gitlab.com/ee/development/internal_analytics/#fundamental-concepts) | [Sample metrics](https://metrics.gitlab.com/) | [Sample events](https://metrics.gitlab.com/snowplow)

Details of events to be tracked:

| Event Description | Event Name | Additional Properties | Feature|
|-------------------|------------|-----------------------|--------|
|  |  |  | |

Details of metrics to be tracked:

|  Metric Description | Event / DB column to base the Metric on | Total or Unique Count of a Property | Time Frame |Feature|
|---------------------|-----------------------------------------|-------------------------------------|------------|-------|
|  |  |  |  | |

<details>
<summary>

**Expand to view examples and guidelines for filling the table**

</summary>

Events:
* **Description:** Include what the event is supposed to track, where and when.
* **Name:** Primary identifier of the event, format: \<**action**\>\_\<**target_of_action**\>\_\<**where/when**\>
   * **Example event name:** click_save_button_in_issue_description_within_15s_of_page_load (**action** = click ; **target** = save button; **where** = in issue description ; **when** = within 15s
* **Additional properties: Besides user/project/namespace, what other details should be tracked, if any? ex) status, type, object id, etc.
* **Feature:** What feature is being instrumented? Please use the feature title that is used in features.yml if thats already available.

Metrics:
* **Description:** What quantitative measurements derived from either event data or database columns would you like to track? eg: Weekly count of unique users who update an issue
* **Event/DB column:** What event or database column should the metric count or be based on.
* **Total or unique count:** Should the metric count all occurrences or only unique counts, e.g. of `user_id` to get a count of unique users triggering an event.
* **Time Frame:** What time frames should be tracked. Default and recommended is 7d and 28d.



</details>

## Next steps

* [ ] Assign an engineering counterpart from your group to add instrumentation to the code
* [ ] Explore instrumented data with the help of our [data discovery guide]( https://docs.gitlab.com/ee/development/internal_analytics/#data-discovery). You can also [reach out to product data insights team](https://gitlab.com/gitlab-data/product-analytics/-/issues/new?issuable_template=PI%20Chart%20Help) for help with generating Tableau reports/dashboards.
* [ ] Your feedback is valuable to us. Please leave us feedback in the comment section of this issue and tag @tjayaramaraju or @basti

# Important links

:star: [Quick start guide to internal events](https://docs.gitlab.com/ee/development/internal_analytics/internal_event_instrumentation/quick_start.html)

:question: [Analytics Instrumentation slack channel for questions](https://gitlab.enterprise.slack.com/archives/CL3A7GFPF)


:writing_hand: Try our [internal events generator](https://docs.gitlab.com/ee/development/internal_analytics/internal_event_instrumentation/quick_start.html#defining-event-and-metrics). Creating event and metric definition files has never been easier.

/label ~"analytics instrumentation"