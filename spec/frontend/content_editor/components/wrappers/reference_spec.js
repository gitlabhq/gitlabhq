import { GlLink } from '@gitlab/ui';
import waitForPromises from 'helpers/wait_for_promises';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import ReferenceWrapper from '~/content_editor/components/wrappers/reference.vue';

describe('content/components/wrappers/reference', () => {
  let wrapper;

  const createWrapper = (node = {}) => {
    wrapper = shallowMountExtended(ReferenceWrapper, {
      propsData: { node },
      provide: {
        contentEditor: {
          resolveReference: jest.fn().mockResolvedValue({
            href: 'https://gitlab.com/gitlab-org/gitlab-test/-/issues/252522',
          }),
        },
      },
    });
  };

  it('renders a span for commands', () => {
    createWrapper({ attrs: { referenceType: 'command', text: '/assign' } });

    const span = wrapper.find('span');
    expect(span.text()).toBe('/assign');
  });

  it('renders an anchor for everything else', () => {
    createWrapper({ attrs: { referenceType: 'issue', text: '#252522' } });

    const link = wrapper.findComponent(GlLink);
    expect(link.text()).toBe('#252522');
  });

  it('adds gfm-project_member class for project members', () => {
    createWrapper({ attrs: { referenceType: 'user', text: '@root' } });

    const link = wrapper.findComponent(GlLink);
    expect(link.text()).toBe('@root');
    expect(link.classes('gfm-project_member')).toBe(true);
    expect(link.classes('current-user')).toBe(false);
  });

  it('adds a current-user class if the project member is current user', () => {
    window.gon = { current_username: 'root' };

    createWrapper({ attrs: { referenceType: 'user', text: '@root' } });

    const link = wrapper.findComponent(GlLink);
    expect(link.text()).toBe('@root');
    expect(link.classes('current-user')).toBe(true);
  });

  it('renders the href of the reference correctly', async () => {
    createWrapper({ attrs: { referenceType: 'issue', text: '#252522' } });
    await waitForPromises();

    const link = wrapper.findComponent(GlLink);
    expect(link.attributes('href')).toBe(
      'https://gitlab.com/gitlab-org/gitlab-test/-/issues/252522',
    );
  });
});
