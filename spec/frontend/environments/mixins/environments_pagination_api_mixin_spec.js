import { shallowMount } from '@vue/test-utils';
import environmentsPaginationApiMixin from '~/environments/mixins/environments_pagination_api_mixin';

describe('environments_pagination_api_mixin', () => {
  const updateContentMock = jest.fn();
  const mockComponent = {
    template: `
      <div>
        <button id='change-page' @click="changePageClick" />
        <button id='change-tab' @click="changeTabClick" />
      </div>
    `,
    methods: {
      updateContent: updateContentMock,
      changePageClick() {
        this.onChangePage(this.nextPage);
      },
      changeTabClick() {
        this.onChangeTab(this.nextScope);
      },
    },
    data() {
      return {
        scope: 'test',
      };
    },
  };

  let wrapper;

  const createWrapper = ({ scope, nextPage, nextScope }) =>
    shallowMount(mockComponent, {
      mixins: [environmentsPaginationApiMixin],
      data() {
        return {
          nextPage,
          nextScope,
          scope,
        };
      },
    });

  it.each([
    ['test-scope', 2],
    ['test-scope', 10],
    ['test-scope-2', 3],
  ])('should call updateContent when calling onChangePage', async (scopeName, pageNumber) => {
    wrapper = createWrapper({ scope: scopeName, nextPage: pageNumber });

    await wrapper.find('#change-page').trigger('click');

    expect(updateContentMock).toHaveBeenCalledWith({
      scope: scopeName,
      page: pageNumber.toString(),
      nested: true,
    });
  });

  it('should call updateContent when calling onChageTab', async () => {
    wrapper = createWrapper({ nextScope: 'stopped' });
    await wrapper.find('#change-tab').trigger('click');

    expect(updateContentMock).toHaveBeenCalledWith({
      scope: 'stopped',
      page: '1',
      nested: true,
    });
  });
});
