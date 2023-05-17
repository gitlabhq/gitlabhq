import { GlSprintf } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import ListItem from '~/vue_shared/components/registry/list_item.vue';
import ClipboardButton from '~/vue_shared/components/clipboard_button.vue';
import TagsListRow from '~/packages_and_registries/harbor_registry/components/tags/tags_list_row.vue';
import { defaultConfig, harborTagsList } from '../../mock_data';

describe('Harbor tag list row', () => {
  let wrapper;

  const findListItem = () => wrapper.findComponent(ListItem);
  const findClipboardButton = () => wrapper.findComponent(ClipboardButton);
  const findByTestId = (testId) => wrapper.findByTestId(testId);

  const $route = {
    params: {
      project: defaultConfig.harborIntegrationProjectName,
      image: 'test-repository',
    },
  };

  const mountComponent = ({ propsData, config = defaultConfig }) => {
    wrapper = shallowMountExtended(TagsListRow, {
      stubs: {
        ListItem,
        GlSprintf,
      },
      propsData,
      mocks: {
        $route,
      },
      provide() {
        return {
          ...config,
        };
      },
    });
  };

  describe('list item', () => {
    beforeEach(() => {
      mountComponent({
        propsData: {
          tag: harborTagsList[0],
        },
      });
    });

    it('exists', () => {
      expect(findListItem().exists()).toBe(true);
    });

    it('has the correct tag name', () => {
      expect(findByTestId('name').text()).toBe(harborTagsList[0].name);
    });

    describe('clipboard button', () => {
      it('exists', () => {
        expect(findClipboardButton().exists()).toBe(true);
      });

      it('has the correct props', () => {
        const pullCommand = `docker pull demo.harbor.com/test-project/test-repository:${harborTagsList[0].name}`;
        expect(findClipboardButton().attributes()).toMatchObject({
          text: pullCommand,
          title: pullCommand,
        });
      });
    });
  });
});
