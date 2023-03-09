import { getByRole } from '@testing-library/dom';
import { mount } from '@vue/test-utils';
import { mockTracking, unmockTracking } from 'helpers/tracking_helper';
import FirstPipelineCard from '~/ci/pipeline_editor/components/drawer/cards/first_pipeline_card.vue';
import { pipelineEditorTrackingOptions } from '~/ci/pipeline_editor/constants';

describe('First pipeline card', () => {
  let wrapper;
  let trackingSpy;

  const createComponent = () => {
    wrapper = mount(FirstPipelineCard);
  };

  const getLinkByName = (name) => getByRole(wrapper.element, 'link', { name });
  const findRunnersLink = () => getLinkByName(/make sure your instance has runners available/i);
  const findInstructionsList = () => wrapper.find('ol');
  const findAllInstructions = () => findInstructionsList().findAll('li');

  beforeEach(() => {
    createComponent();
  });

  it('renders the title', () => {
    expect(wrapper.text()).toContain(wrapper.vm.$options.i18n.title);
  });

  it('renders the content', () => {
    expect(findInstructionsList().exists()).toBe(true);
    expect(findAllInstructions()).toHaveLength(3);
  });

  it('renders the link', () => {
    expect(findRunnersLink().href).toBe(wrapper.vm.$options.RUNNER_HELP_URL);
  });

  describe('tracking', () => {
    beforeEach(() => {
      createComponent();
      trackingSpy = mockTracking(undefined, wrapper.element, jest.spyOn);
    });

    afterEach(() => {
      unmockTracking();
    });

    it('tracks runners help page click', async () => {
      const { label } = pipelineEditorTrackingOptions;
      const { runners } = pipelineEditorTrackingOptions.actions.helpDrawerLinks;

      await findRunnersLink().click();

      expect(trackingSpy).toHaveBeenCalledWith(undefined, runners, { label });
    });
  });
});
