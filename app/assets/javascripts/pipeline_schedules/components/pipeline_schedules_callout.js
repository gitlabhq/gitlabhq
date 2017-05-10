import Cookies from 'js-cookie';
import illustrationSvg from '../icons/intro_illustration.svg';

const cookieKey = 'pipeline_schedules_callout_dismissed';

export default {
  data() {
    return {
      illustrationSvg,
      calloutDismissed: Cookies.get(cookieKey) === 'true',
    };
  },
  methods: {
    dismissCallout() {
      this.calloutDismissed = true;
      Cookies.set(cookieKey, this.calloutDismissed, { expires: 365 });
    },
  },
  template: `
    <div v-if="!calloutDismissed" class="pipeline-schedules-user-callout user-callout">
      <div class="bordered-box landing content-block">
        <button
          id="dismiss-callout-btn"
          class="btn btn-default close"
          @click="dismissCallout">
          <i class="fa fa-times"></i>
        </button>
        <div class="svg-container" v-html="illustrationSvg"></div>
        <div class="user-callout-copy">
          <h4>Scheduling Pipelines</h4>
          <p> 
              The pipelines schedule runs pipelines in the future, repeatedly, for specific branches or tags. 
              Those scheduled pipelines will inherit limited project access based on their associated user.
          </p>
          <p> Learn more in the
            <!-- FIXME -->
            <a href="random.com">pipeline schedules documentation</a>.
          </p>
        </div>
      </div>
    </div>
  `,
};

