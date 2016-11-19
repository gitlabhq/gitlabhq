/* eslint-disable no-param-reassign */
((global) => {
  global.cycleAnalytics = global.cycleAnalytics || {};

  global.cycleAnalytics.StageTestComponent = Vue.extend({
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
              <h5 class="item-title">
                <span class="icon-build-status">
                  <svg xmlns="http://www.w3.org/2000/svg" width="14" height="14">
                    <g fill="#31AF64" fill-rule="evenodd">
                      <path d="M12.5 7c0-3.038-2.462-5.5-5.5-5.5S1.5 3.962 1.5 7s2.462 5.5 5.5 5.5 5.5-2.462 5.5-5.5zM0 7c0-3.866 3.134-7 7-7s7 3.134 7 7-3.134 7-7 7-7-3.134-7-7z"/>
                      <path d="M6.28 7.697L5.045 6.464c-.117-.117-.305-.117-.42-.002l-.614.614c-.112.113-.113.303.004.42l1.91 1.91c.19.19.51.197.703.004l.265-.265L9.997 6.04c.108-.107.107-.293-.01-.408l-.612-.614c-.114-.113-.298-.12-.41-.01L6.28 7.7z"/>
                    </g>
                  </svg>
                </span>
                <a :href="build.url"  class="item-build-name">{{ build.name }}</a>
                &middot;
                <a href="#" class="pipeline-id">#{{ build.id }}</a>
                <i class="fa fa-code-fork"></i>
                <a :href="build.branch.url" class="branch-name monospace">{{ build.branch.name }}</a>
                <span class="icon-branch">
                  <svg xmlns="http://www.w3.org/2000/svg" width="14" height="14">
                    <path fill="#8C8C8C" fill-rule="evenodd" d="M9.678 6.722C9.353 5.167 8.053 4 6.5 4S3.647 5.167 3.322 6.722h-2.6c-.397 0-.722.35-.722.778 0 .428.325.778.722.778h2.6C3.647 9.833 4.947 11 6.5 11s2.853-1.167 3.178-2.722h2.6c.397 0 .722-.35.722-.778 0-.428-.325-.778-.722-.778h-2.6zM4.694 7.5c0-1.09.795-1.944 1.806-1.944 1.01 0 1.806.855 1.806 1.944 0 1.09-.795 1.944-1.806 1.944-1.01 0-1.806-.855-1.806-1.944z"/>
                  </svg>
                </span>
                <a :href="build.commitUrl" class="short-sha monospace">{{ build.shortSha }}</a>
              </h5>
              <span>
                <a :href="build.url" class="issue-date">
                  {{ build.date }}
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
