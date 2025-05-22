import VueApollo from 'vue-apollo';
import Vue from 'vue';
import { mountExtended } from 'helpers/vue_test_utils_helper';
import LiveBlock from '~/gitlab_pages/components/live_block.vue';
import CrudComponent from '~/vue_shared/components/crud_component.vue';
import TimeAgo from '~/vue_shared/components/time_ago_tooltip.vue';
import { primaryDeployment } from '../mock_data';

Vue.use(VueApollo);

describe('PagesLiveBlock', () => {
  let wrapper;

  const createComponent = ({ provide = {} } = {}) => {
    wrapper = mountExtended(LiveBlock, {
      propsData: {
        deployment: primaryDeployment,
      },
      provide: {
        projectFullPath: 'my-group/my-project',
        primaryDomain: null,
        ...provide,
      },
      stubs: {
        CrudComponent,
        TimeAgo,
      },
    });
  };

  const findHeading = () => wrapper.findByTestId('live-heading');
  const findHeadingLink = () => wrapper.findByTestId('live-heading-link');
  const findDeployJobNumber = () => wrapper.findByTestId('deploy-job-number');
  const findUpdatedAt = () => wrapper.findComponent(TimeAgo);
  const findVisitSite = () => wrapper.findByTestId('visit-site-url');

  describe('displays expected data', () => {
    beforeEach(() => {
      createComponent();
    });

    it('renders heading', () => {
      expect(findHeading().text().replace(/\s+/g, ' ')).toBe(
        `Your Pages site is live at ${primaryDeployment.url} 🎉`,
      );
      expect(findHeadingLink().attributes('href')).toBe(primaryDeployment.url);
    });

    it('renders deploy job number and link', () => {
      expect(findDeployJobNumber().text()).toBe(primaryDeployment.ciBuildId.toString());
      expect(findDeployJobNumber().attributes('href')).toBe('/my-group/my-project/-/jobs/123');
    });

    it('renders updated at', () => {
      expect(findUpdatedAt().props('time')).toBe(primaryDeployment.updatedAt);
    });

    it('renders visit site button', () => {
      expect(findVisitSite().text()).toBe('Visit site');
      expect(findVisitSite().attributes('href')).toBe(primaryDeployment.url);
    });

    it('uses primaryDomain when set', () => {
      const primaryDomain = 'https://primary.domain';

      createComponent({
        provide: {
          primaryDomain,
        },
      });

      expect(findHeading().text().replace(/\s+/g, ' ')).toBe(
        `Your Pages site is live at ${primaryDomain} 🎉`,
      );
      expect(findHeadingLink().attributes('href')).toBe(primaryDomain);
      expect(findVisitSite().attributes('href')).toBe(primaryDomain);
    });
  });
});
