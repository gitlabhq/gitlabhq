import { shallowMount } from '@vue/test-utils';
import { GlButton } from '@gitlab/ui';
import HelpState from '~/sidebar/components/time_tracking/help_state.vue';
import { joinPaths } from '~/lib/utils/url_utility';
import { sprintf } from '~/locale';
import SafeHtml from '~/vue_shared/directives/safe_html';

jest.mock('~/lib/utils/url_utility', () => ({
  joinPaths: jest.fn(),
}));

jest.mock('~/locale', () => ({
  ...jest.requireActual('~/locale'),
  sprintf: jest.fn((template, variables) => `${template} ${JSON.stringify(variables)}`),
}));

describe('Time Tracking Help State', () => {
  let wrapper;

  const findHeader = () => wrapper.find('h4');
  const findParagraphs = () => wrapper.findAll('p');
  const findParagraphInfo = () => findParagraphs().at(0);
  const findParagraphEstimate = () => findParagraphs().at(1);
  const findParagraphSpend = () => findParagraphs().at(2);
  const findButtonLearnMore = () => wrapper.findComponent(GlButton);

  const expectedText = {
    header: 'Track time with quick actions',
    paragraphInfo: 'Quick actions can be used in description and comment boxes.',
    estimate: 'overwrites the total estimated time.',
    spend: 'adds or subtracts time already spent.',
    learnMore: 'Learn more',
  };

  function createComponent() {
    wrapper = shallowMount(HelpState, {
      directives: {
        SafeHtml,
      },
    });
  }

  beforeEach(() => {
    createComponent();
  });

  it('renders the component correctly', () => {
    expect(wrapper.exists()).toBe(true);
  });

  it('renders the header correctly', () => {
    expect(findHeader().text()).toBe(expectedText.header);
    expect(findParagraphInfo().text()).toBe(expectedText.paragraphInfo);
  });

  it('renders estimate text with the correct HTML content', () => {
    expect(sprintf).toHaveBeenCalledWith(
      `%{slash_command} ${expectedText.estimate}`,
      { slash_command: '<code>/estimate</code>' },
      false,
    );

    expect(findParagraphEstimate().html()).toContain(expectedText.estimate);
  });

  it('renders spend text with the correct HTML content', () => {
    expect(sprintf).toHaveBeenCalledWith(
      `%{slash_command} ${expectedText.spend}`,
      { slash_command: '<code>/spend</code>' },
      false,
    );
    expect(findParagraphSpend().html()).toContain(expectedText.spend);
  });

  it('should display Learn More button', () => {
    expect(findButtonLearnMore().exists()).toBe(true);
  });

  it('renders the button with the correct href', () => {
    const href = '/help/user/project/time_tracking.md';

    expect(joinPaths).toHaveBeenCalledWith('', href);
  });

  it('renders the button text correctly', () => {
    expect(findButtonLearnMore().text()).toBe(expectedText.learnMore);
  });
});
