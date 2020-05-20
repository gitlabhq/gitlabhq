import Vue from 'vue';
import Cookies from 'js-cookie';
import PipelineSchedulesCallout from '~/pages/projects/pipeline_schedules/shared/components/pipeline_schedules_callout.vue';
import '~/pages/projects/pipeline_schedules/shared/icons/intro_illustration.svg';

jest.mock(
  '~/pages/projects/pipeline_schedules/shared/icons/intro_illustration.svg',
  () => '<svg></svg>',
);

const PipelineSchedulesCalloutComponent = Vue.extend(PipelineSchedulesCallout);
const cookieKey = 'pipeline_schedules_callout_dismissed';
const docsUrl = 'help/ci/scheduled_pipelines';

describe('Pipeline Schedule Callout', () => {
  let calloutComponent;

  beforeEach(() => {
    setFixtures(`
      <div id='pipeline-schedules-callout' data-docs-url=${docsUrl}></div>
    `);
  });

  describe('independent of cookies', () => {
    beforeEach(() => {
      calloutComponent = new PipelineSchedulesCalloutComponent().$mount();
    });

    it('the component can be initialized', () => {
      expect(calloutComponent).toBeDefined();
    });

    it('correctly sets illustrationSvg', () => {
      expect(calloutComponent.illustrationSvg).toContain('<svg');
    });

    it('correctly sets docsUrl', () => {
      expect(calloutComponent.docsUrl).toContain(docsUrl);
    });
  });

  describe(`when ${cookieKey} cookie is set`, () => {
    beforeEach(() => {
      Cookies.set(cookieKey, true);
      calloutComponent = new PipelineSchedulesCalloutComponent().$mount();
    });

    it('correctly sets calloutDismissed to true', () => {
      expect(calloutComponent.calloutDismissed).toBe(true);
    });

    it('does not render the callout', () => {
      expect(calloutComponent.$el.childNodes.length).toBe(0);
    });
  });

  describe('when cookie is not set', () => {
    beforeEach(() => {
      Cookies.remove(cookieKey);
      calloutComponent = new PipelineSchedulesCalloutComponent().$mount();
    });

    it('correctly sets calloutDismissed to false', () => {
      expect(calloutComponent.calloutDismissed).toBe(false);
    });

    it('renders the callout container', () => {
      expect(calloutComponent.$el.querySelector('.bordered-box')).not.toBeNull();
    });

    it('renders the callout svg', () => {
      expect(calloutComponent.$el.outerHTML).toContain('<svg');
    });

    it('renders the callout title', () => {
      expect(calloutComponent.$el.outerHTML).toContain('Scheduling Pipelines');
    });

    it('renders the callout text', () => {
      expect(calloutComponent.$el.outerHTML).toContain('runs pipelines in the future');
    });

    it('renders the documentation url', () => {
      expect(calloutComponent.$el.outerHTML).toContain(docsUrl);
    });

    it('updates calloutDismissed when close button is clicked', done => {
      calloutComponent.$el.querySelector('#dismiss-callout-btn').click();

      Vue.nextTick(() => {
        expect(calloutComponent.calloutDismissed).toBe(true);
        done();
      });
    });

    it('#dismissCallout updates calloutDismissed', done => {
      calloutComponent.dismissCallout();

      Vue.nextTick(() => {
        expect(calloutComponent.calloutDismissed).toBe(true);
        done();
      });
    });

    it('is hidden when close button is clicked', done => {
      calloutComponent.$el.querySelector('#dismiss-callout-btn').click();

      Vue.nextTick(() => {
        expect(calloutComponent.$el.childNodes.length).toBe(0);
        done();
      });
    });
  });
});
