import { nextTick } from 'vue';
import { mount } from '@vue/test-utils';
import { GlTabs } from '@gitlab/ui';

import EditorTab from '~/pipeline_editor/components/ui/editor_tab.vue';

const mockContent1 = 'MOCK CONTENT 1';
const mockContent2 = 'MOCK CONTENT 2';

describe('~/pipeline_editor/components/ui/editor_tab.vue', () => {
  let wrapper;
  let mockChildMounted = jest.fn();

  const MockChild = {
    props: ['content'],
    template: '<div>{{content}}</div>',
    mounted() {
      mockChildMounted(this.content);
    },
  };

  const MockTabbedContent = {
    components: {
      EditorTab,
      GlTabs,
      MockChild,
    },
    template: `
        <gl-tabs>
          <editor-tab :title-link-attributes="{ 'data-testid': 'tab1-btn' }" :lazy="true">
            <mock-child content="${mockContent1}"/>
          </editor-tab>
          <editor-tab :title-link-attributes="{ 'data-testid': 'tab2-btn' }" :lazy="true">
            <mock-child content="${mockContent2}"/>
          </editor-tab>
        </gl-tabs>
      `,
  };

  const createWrapper = () => {
    wrapper = mount(MockTabbedContent);
  };

  beforeEach(() => {
    mockChildMounted = jest.fn();
  });

  it('tabs are mounted lazily', async () => {
    createWrapper();

    expect(mockChildMounted).toHaveBeenCalledTimes(0);
  });

  it('first tab is only mounted after nextTick', async () => {
    createWrapper();

    await nextTick();

    expect(mockChildMounted).toHaveBeenCalledTimes(1);
    expect(mockChildMounted).toHaveBeenCalledWith(mockContent1);
  });

  describe('user interaction', () => {
    const clickTab = async (testid) => {
      wrapper.find(`[data-testid="${testid}"]`).trigger('click');
      await nextTick();
    };

    beforeEach(() => {
      createWrapper();
    });

    it('mounts a tab once after selecting it', async () => {
      await clickTab('tab2-btn');

      expect(mockChildMounted).toHaveBeenCalledTimes(2);
      expect(mockChildMounted).toHaveBeenNthCalledWith(1, mockContent1);
      expect(mockChildMounted).toHaveBeenNthCalledWith(2, mockContent2);
    });

    it('mounts each tab once after selecting each', async () => {
      await clickTab('tab2-btn');
      await clickTab('tab1-btn');
      await clickTab('tab2-btn');

      expect(mockChildMounted).toHaveBeenCalledTimes(2);
      expect(mockChildMounted).toHaveBeenNthCalledWith(1, mockContent1);
      expect(mockChildMounted).toHaveBeenNthCalledWith(2, mockContent2);
    });
  });
});
