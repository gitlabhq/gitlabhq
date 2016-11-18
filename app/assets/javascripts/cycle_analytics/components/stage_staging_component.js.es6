((global) => {

  global.cycleAnalytics = global.cycleAnalytics || {};

  global.cycleAnalytics.StageStagingComponent = Vue.extend({
    props: {
      items: Array,
      stage: Object,
    },
    template: `
      <div>
        <div class="events-description">
          {{ stage.description }}
        </div>
        <ul class="stage-event-list">
          <li v-for="build in items" class="stage-event-item item-build-component">
            <div class="item-details">
              <img class="avatar" :src="build.author.avatarUrl">
              <h5 class="item-title">
                <a :href="build.url" class="pipeline-id">
                  #{{ build.iid }}
                </a>
                <i class="fa fa-code-fork"></i>
                <a :href="build.branch.url" class="branch-name monospace">{{ build.branch.name }}</a>
                <span class="icon-branch">
                  <svg xmlns="http://www.w3.org/2000/svg" width="14" height="14">
                    <path fill="#8C8C8C" fill-rule="evenodd" d="M9.678 6.722C9.353 5.167 8.053 4 6.5 4S3.647 5.167 3.322 6.722h-2.6c-.397 0-.722.35-.722.778 0 .428.325.778.722.778h2.6C3.647 9.833 4.947 11 6.5 11s2.853-1.167 3.178-2.722h2.6c.397 0 .722-.35.722-.778 0-.428-.325-.778-.722-.778h-2.6zM4.694 7.5c0-1.09.795-1.944 1.806-1.944 1.01 0 1.806.855 1.806 1.944 0 1.09-.795 1.944-1.806 1.944-1.01 0-1.806-.855-1.806-1.944z"/>
                  </svg>
                </span>
                <a :href="build.commitUrl" class="short-sha monospace">da57eb39</a>
              </h5>
              <span>
                <a :href="build.url" class="issue-date">
                  {{ build.createdAt }}
                </a>
                by
                <a :href="build.author.webUrl" class="issue-author-link">
                  {{ build.author.name }}
                </a>
              </span>
            </div>
            <div class="item-time">
              <total-time :time="build.totalTime"></total-time>
            </div>
          </li>
        </ul>
      </div>
    `,
  });

})(window.gl || (window.gl = {}));
