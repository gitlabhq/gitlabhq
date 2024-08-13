import Vue, { nextTick } from 'vue';
// eslint-disable-next-line no-restricted-imports
import Vuex from 'vuex';
import { GlModal } from '@gitlab/ui';
import originalOneReleaseForEditingQueryResponse from 'test_fixtures/graphql/releases/graphql/queries/one_release_for_editing.query.graphql.json';
import { convertOneReleaseGraphQLResponse } from '~/releases/util';
import ConfirmDeleteModal from '~/releases/components/confirm_delete_modal.vue';
import { mountExtended } from 'helpers/vue_test_utils_helper';
import { sprintf } from '~/locale';

Vue.use(Vuex);

const release = convertOneReleaseGraphQLResponse(originalOneReleaseForEditingQueryResponse).data;
const deleteReleaseDocsPath = 'path/to/delete/release/docs';

describe('~/releases/components/confirm_delete_modal.vue', () => {
  let wrapper;
  let state;

  const factory = async () => {
    state = {
      release,
      deleteReleaseDocsPath,
    };

    const store = new Vuex.Store({
      modules: {
        editNew: {
          namespaced: true,
          state,
        },
      },
    });

    wrapper = mountExtended(ConfirmDeleteModal, {
      store,
    });

    await nextTick();
  };

  beforeEach(() => {
    factory();
  });

  describe('button', () => {
    it('should open the modal on click', async () => {
      await wrapper.findByRole('button', { name: 'Delete' }).trigger('click');

      const title = wrapper.findByText(
        sprintf('Delete release %{release}?', { release: release.name }),
      );

      expect(title.exists()).toBe(true);
    });
  });

  describe('modal', () => {
    beforeEach(async () => {
      await wrapper.findByRole('button', { name: 'Delete' }).trigger('click');
    });

    it('confirms the user wants to delete the release', () => {
      const text = wrapper.findByText('Are you sure you want to delete this release?');

      expect(text.exists()).toBe(true);
    });

    it('links to the tag', () => {
      const tagPath = wrapper.findByRole('link', { name: release.tagName });
      expect(tagPath.attributes('href')).toBe(release.tagPath);
    });

    it('links to the docs on deleting releases', () => {
      const docsPath = wrapper.findByRole('link', { name: 'Deleting a release' });

      expect(docsPath.attributes('href')).toBe(deleteReleaseDocsPath);
    });

    it('emits a delete event on action primary', () => {
      wrapper.findComponent(GlModal).vm.$emit('primary');

      expect(wrapper.emitted('delete')).toEqual([[]]);
    });
  });
});
