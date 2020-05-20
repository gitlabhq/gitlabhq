import { TEST_HOST } from 'helpers/test_constants';
import renderMetrics from '~/behaviors/markdown/render_metrics';

const mockEmbedGroup = jest.fn();

jest.mock('vue', () => ({ extend: () => mockEmbedGroup }));
jest.mock('~/monitoring/components/embeds/embed_group.vue', () => jest.fn());
jest.mock('~/monitoring/stores/embed_group/', () => ({ createStore: jest.fn() }));

const getElements = () => Array.from(document.getElementsByClassName('js-render-metrics'));

describe('Render metrics for Gitlab Flavoured Markdown', () => {
  it('does nothing when no elements are found', () => {
    return renderMetrics([]).then(() => {
      expect(mockEmbedGroup).not.toHaveBeenCalled();
    });
  });

  it('renders a vue component when elements are found', () => {
    document.body.innerHTML = `<div class="js-render-metrics" data-dashboard-url="${TEST_HOST}"></div>`;

    return renderMetrics(getElements()).then(() => {
      expect(mockEmbedGroup).toHaveBeenCalledTimes(1);
      expect(mockEmbedGroup).toHaveBeenCalledWith(
        expect.objectContaining({ propsData: { urls: [`${TEST_HOST}`] } }),
      );
    });
  });

  it('takes sibling metrics and groups them under a shared parent', () => {
    document.body.innerHTML = `
      <p><span>Hello</span></p>
      <div class="js-render-metrics" data-dashboard-url="${TEST_HOST}/1"></div>
      <div class="js-render-metrics" data-dashboard-url="${TEST_HOST}/2"></div>
      <p><span>Hello</span></p>
      <div class="js-render-metrics" data-dashboard-url="${TEST_HOST}/3"></div>
    `;

    return renderMetrics(getElements()).then(() => {
      expect(mockEmbedGroup).toHaveBeenCalledTimes(2);
      expect(mockEmbedGroup).toHaveBeenCalledWith(
        expect.objectContaining({ propsData: { urls: [`${TEST_HOST}/1`, `${TEST_HOST}/2`] } }),
      );
      expect(mockEmbedGroup).toHaveBeenCalledWith(
        expect.objectContaining({ propsData: { urls: [`${TEST_HOST}/3`] } }),
      );
    });
  });
});
