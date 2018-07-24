import Vue from 'vue';
import _ from 'underscore';
import initGroupMemberContributions from 'ee/group_member_contributions';
import BarChart from '~/vue_shared/components/bar_chart.vue';
import { __ } from '~/locale';

function sortByValue(data) {
  return _.sortBy(data, 'value').reverse();
}

function allValuesEmpty(graphData) {
  const emptyCount = graphData.reduce((acc, data) => acc + Math.min(0, data.value), 0);

  return emptyCount === 0;
}

document.addEventListener('DOMContentLoaded', () => {
  const dataEl = document.getElementById('js-analytics-data');
  if (dataEl) {
    const data = JSON.parse(dataEl.innerHTML);
    const outputElIds = ['push', 'issues_closed', 'merge_requests_created'];
    const formattedData = {
      push: [],
      issues_closed: [],
      merge_requests_created: [],
    };

    outputElIds.forEach((id) => {
      data[id].data.forEach((d, index) => {
        formattedData[id].push({
          name: data.labels[index],
          value: d,
        });
      });
    });

    initGroupMemberContributions();

    const pushesEl = document.getElementById('js_pushes_chart_vue');
    if (allValuesEmpty(formattedData.push)) {
      // eslint-disable-next-line no-new
      new Vue({
        el: pushesEl,
        components: {
          BarChart,
        },
        render(createElement) {
          return createElement('bar-chart', {
            props: {
              graphData: sortByValue(formattedData.push),
              yAxisLabel: __('Pushes'),
            },
          });
        },
      });
    }

    const mergeRequestEl = document.getElementById('js_merge_requests_chart_vue');
    if (allValuesEmpty(formattedData.merge_requests_created)) {
      // eslint-disable-next-line no-new
      new Vue({
        el: mergeRequestEl,
        components: {
          BarChart,
        },
        render(createElement) {
          return createElement('bar-chart', {
            props: {
              graphData: sortByValue(formattedData.merge_requests_created),
              yAxisLabel: __('Merge Requests created'),
            },
          });
        },
      });
    }

    const issueEl = document.getElementById('js_issues_chart_vue');
    if (allValuesEmpty(formattedData.issues_closed)) {
      // eslint-disable-next-line no-new
      new Vue({
        el: issueEl,
        components: {
          BarChart,
        },
        render(createElement) {
          return createElement('bar-chart', {
            props: {
              graphData: sortByValue(formattedData.issues_closed),
              yAxisLabel: __('Issues closed'),
            },
          });
        },
      });
    }
  }
});
