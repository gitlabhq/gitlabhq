import { shallowMount } from '@vue/test-utils';
import { GlModal } from '@gitlab/ui';
import DeleteWikiModal from '~/pages/shared/wikis/components/delete_wiki_modal.vue';
import { mockLocation, restoreLocation } from '../test_utils';

describe('DeleteWikiModal', () => {
  let wrapper;
  let glModalDirective;

  const createComponent = () => {
    glModalDirective = jest.fn();

    wrapper = shallowMount(DeleteWikiModal, {
      directives: {
        glModal: {
          bind(_, { value }) {
            glModalDirective(value);
          },
        },
      },
      provide: {
        wikiUrl: 'delete-wiki-url',
        pageHeading: 'Page title',
        csrfToken: 'csrf-token',
        pagePersisted: true,
      },
    });
  };

  const findDeleteModal = () => wrapper.findComponent(GlModal);

  it('renders a delete modal', () => {
    const modalId = 'delete-wiki-modal';

    createComponent();

    expect(findDeleteModal().props('modalId')).toBe(modalId);
    expect(glModalDirective).toHaveBeenCalledWith(modalId);
  });

  it('shows correct title and modal text when page is a template', () => {
    mockLocation('http://gitlab.com/gitlab-org/gitlab/-/wikis/templates/abc');

    createComponent();

    expect(findDeleteModal().props('title')).toBe('Delete template "Page title"?');
    expect(findDeleteModal().text()).toContain('Are you sure you want to delete this template?');

    restoreLocation();
  });

  it('shows correct title and modal text when page is not a template', () => {
    mockLocation('http://gitlab.com/gitlab-org/gitlab/-/wikis/abc');

    createComponent();

    expect(findDeleteModal().props('title')).toBe('Delete page "Page title"?');
    expect(findDeleteModal().text()).toContain('Are you sure you want to delete this page?');

    restoreLocation();
  });
});
