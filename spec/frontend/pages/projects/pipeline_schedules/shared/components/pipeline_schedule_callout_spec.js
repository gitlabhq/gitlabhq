import { GlButton } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import Cookies from 'js-cookie';
import PipelineSchedulesCallout from '~/pages/projects/pipeline_schedules/shared/components/pipeline_schedules_callout.vue';

const cookieKey = 'pipeline_schedules_callout_dismissed';
const docsUrl = 'help/ci/scheduled_pipelines';
const illustrationUrl = 'pages/projects/pipeline_schedules/shared/icons/intro_illustration.svg';

describe('Pipeline Schedule Callout', () => {
  let wrapper;

  const createComponent = () => {
    wrapper = shallowMount(PipelineSchedulesCallout, {
      provide: {
        docsUrl,
        illustrationUrl,
      },
    });
  };

  const findInnerContentOfCallout = () => wrapper.find('[data-testid="innerContent"]');
  const findDismissCalloutBtn = () => wrapper.find(GlButton);

  describe(`when ${cookieKey} cookie is set`, () => {
    beforeEach(async () => {
      Cookies.set(cookieKey, true);
      createComponent();

      await wrapper.vm.$nextTick();
    });

    afterEach(() => {
      wrapper.destroy();
    });

    it('does not render the callout', () => {
      expect(findInnerContentOfCallout().exists()).toBe(false);
    });
  });

  describe('when cookie is not set', () => {
    beforeEach(() => {
      Cookies.remove(cookieKey);
      createComponent();
    });

    afterEach(() => {
      wrapper.destroy();
    });

    it('renders the callout container', () => {
      expect(findInnerContentOfCallout().exists()).toBe(true);
    });

    it('renders the callout title', () => {
      expect(wrapper.find('h4').text()).toBe('Scheduling Pipelines');
    });

    it('renders the callout text', () => {
      expect(wrapper.find('p').text()).toContain('runs pipelines in the future');
    });

    it('renders the documentation url', () => {
      expect(wrapper.find('a').attributes('href')).toBe(docsUrl);
    });

    describe('methods', () => {
      it('#dismissCallout sets calloutDismissed to true', async () => {
        expect(wrapper.vm.calloutDismissed).toBe(false);

        findDismissCalloutBtn().vm.$emit('click');

        await wrapper.vm.$nextTick();

        expect(findInnerContentOfCallout().exists()).toBe(false);
      });

      it('sets cookie on dismiss', () => {
        const setCookiesSpy = jest.spyOn(Cookies, 'set');

        findDismissCalloutBtn().vm.$emit('click');

        expect(setCookiesSpy).toHaveBeenCalledWith('pipeline_schedules_callout_dismissed', true, {
          expires: 365,
        });
      });
    });

    it('is hidden when close button is clicked', async () => {
      findDismissCalloutBtn().vm.$emit('click');

      await wrapper.vm.$nextTick();

      expect(findInnerContentOfCallout().exists()).toBe(false);
    });
  });
});
