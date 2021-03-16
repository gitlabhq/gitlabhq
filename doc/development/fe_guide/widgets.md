---
stage: none
group: unassigned
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
---

# Widgets

Frontend widgets are standalone Vue applications or Vue component trees that can be added on a page
to handle a part of the functionality.

Good examples of widgets are [sidebar assignees](https://gitlab.com/gitlab-org/gitlab/-/blob/master/app/assets/javascripts/sidebar/components/assignees/sidebar_assignees_widget.vue) and [sidebar confidentiality](https://gitlab.com/gitlab-org/gitlab/-/blob/master/app/assets/javascripts/sidebar/components/confidential/sidebar_confidentiality_widget.vue).

When building a widget, we should follow a few principles described below.

## Vue Apollo is required

All widgets should use the same stack (Vue + Apollo Client).
To make it happen, we must add Vue Apollo to the application root (if we use a widget
as a component) or provide it directly to a widget. For sidebar widgets, use the
[sidebar Apollo Client and Apollo Provider](https://gitlab.com/gitlab-org/gitlab/-/blob/master/app/assets/javascripts/sidebar/graphql.js):

```javascript
import SidebarConfidentialityWidget from '~/sidebar/components/confidential/sidebar_confidentiality_widget.vue';
import { apolloProvider } from '~/sidebar/graphql';

function mountConfidentialComponent() {
  new Vue({
    apolloProvider,
    components: {
      SidebarConfidentialityWidget,
    },
    /* ... */
  });
}
```

## Required injections

All editable sidebar widgets should use [`SidebarEditableItem`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/app/assets/javascripts/sidebar/components/sidebar_editable_item.vue) to handle collapsed/expanded state. This component requires the `canUpdate` property provided in the application root.

## No global state mappings

We aim to make widgets as reusable as possible. That's why we should avoid adding any external state
bindings to widgets or to their child components. This includes Vuex mappings and mediator stores.

## Widget's responsibility

A widget is responsible for fetching and updating an entity it's designed for (assignees, iterations, and so on).
This means a widget should **always** fetch data (if it's not in Apollo cache already).
Even if we provide an initial value to the widget, it should perform a GraphQL query in the background
to be stored in Apollo cache.

Eventually, when we have an Apollo Client cache as a global application state, we won't need to pass
initial data to the sidebar widget. Then it will be capable of retrieving the data from the cache.

## Using GraphQL queries and mutations

We need widgets to be flexible to work with different entities (epics, issues, merge requests, and so on).
Because we need different GraphQL queries and mutations for different sidebars, we create
[_mappings_](https://gitlab.com/gitlab-org/gitlab/-/blob/master/app/assets/javascripts/sidebar/constants.js#L9):

```javascript
export const assigneesQueries = {
  [IssuableType.Issue]: {
    query: getIssueParticipants,
    mutation: updateAssigneesMutation,
  },
  [IssuableType.MergeRequest]: {
    query: getMergeRequestParticipants,
    mutation: updateMergeRequestParticipantsMutation,
  },
};
```

To handle the same logic for query updates, we **alias** query fields. For example:

- `group` or `project` become `workspace`
- `issue`, `epic`, or `mergeRequest` become `issuable`

Unfortunately, Apollo assigns aliased fields a typename of `undefined`, so we need to fetch `__typename` explicitly:

```plaintext
query issueConfidential($fullPath: ID!, $iid: String) {
  workspace: project(fullPath: $fullPath) {
    __typename
    issuable: issue(iid: $iid) {
      __typename
      id
      confidential
    }
  }
}
```

## Communication with other Vue applications

If we need to communicate the changes of the widget state (for example, after successful mutation)
to the parent application, we should emit an event:

```javascript
updateAssignees(assigneeUsernames) {
  return this.$apollo
    .mutate({
      mutation: this.$options.assigneesQueries[this.issuableType].mutation,
      variables: {...},
    })
    .then(({ data }) => {
      const assignees = data.issueSetAssignees?.issue?.assignees?.nodes || [];
      this.$emit('assignees-updated', assignees);
    })
}
```

Sometimes, we want to listen to the changes on the different Vue application like `NotesApp`.
In this case, we can use a renderless component that imports a client and listens to a certain query:

```javascript
import { fetchPolicies } from '~/lib/graphql';
import { confidentialityQueries } from '~/sidebar/constants';
import { defaultClient as gqlClient } from '~/sidebar/graphql';

created() {
  if (this.issuableType !== IssuableType.Issue) {
    return;
  }

  gqlClient
    .watchQuery({
      query: confidentialityQueries[this.issuableType].query,
      variables: {...},
      fetchPolicy: fetchPolicies.CACHE_ONLY,
    })
    .subscribe((res) => {
      this.setConfidentiality(issuable.confidential);
    });
},
methods: {
  ...mapActions(['setConfidentiality']),
},
```

[View an example of such a component.](https://gitlab.com/gitlab-org/gitlab/-/blob/master/app/assets/javascripts/notes/components/sidebar_subscription.vue)
