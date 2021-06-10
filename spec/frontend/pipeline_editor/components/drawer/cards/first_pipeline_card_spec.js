import { getByRole } from '@testing-library/dom';
import { mount } from '@vue/test-utils';
import FirstPipelineCard from '~/pipeline_editor/components/drawer/cards/first_pipeline_card.vue';

describe('First pipeline card', () => {
  let wrapper;

  const defaultProvide = {
    runnerHelpPagePath: '/help/runners',
  };

  const createComponent = () => {
    wrapper = mount(FirstPipelineCard, {
      provide: {
        ...defaultProvide,
      },
    });
  };

  const getLinkByName = (name) => getByRole(wrapper.element, 'link', { name }).href;
  const findRunnersLink = () => getLinkByName(/make sure your instance has runners available/i);
  const findInstructionsList = () => wrapper.find('ol');
  const findAllInstructions = () => findInstructionsList().findAll('li');

  beforeEach(() => {
    createComponent();
  });

  afterEach(() => {
    wrapper.destroy();
  });

  it('renders the title', () => {
    expect(wrapper.text()).toContain(wrapper.vm.$options.i18n.title);
  });

  it('renders the content', () => {
    expect(findInstructionsList().exists()).toBe(true);
    expect(findAllInstructions()).toHaveLength(3);
  });

  it('renders the link', () => {
    expect(findRunnersLink()).toContain(defaultProvide.runnerHelpPagePath);
  });
});
