import { GlEmptyState, GlLink } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import EmptyStateSignedOut from '~/issues/list/components/empty_state_signed_out.vue';
import { i18n } from '~/issues/list/constants';

describe('EmptyStateSignedOut component', () => {
  let wrapper;

  const defaultProvide = {
    emptyStateSvgPath: 'empty/state/svg/path',
    signInPath: 'sign/in/path',
  };

  const findGlEmptyState = () => wrapper.findComponent(GlEmptyState);
  const findGlLink = () => wrapper.findComponent(GlLink);

  const mountComponent = () => shallowMount(EmptyStateSignedOut, { provide: defaultProvide });

  beforeEach(() => {
    wrapper = mountComponent();
  });

  it('renders empty state', () => {
    expect(findGlEmptyState().props()).toMatchObject({
      title: i18n.noIssuesTitle,
      svgPath: defaultProvide.emptyStateSvgPath,
      primaryButtonText: i18n.noIssuesSignedOutButtonText,
      primaryButtonLink: defaultProvide.signInPath,
    });
  });

  it('renders issues docs link', () => {
    expect(findGlLink().attributes('href')).toBe(EmptyStateSignedOut.issuesHelpPagePath);
    expect(findGlLink().text()).toBe(i18n.noIssuesDescription);
  });
});
