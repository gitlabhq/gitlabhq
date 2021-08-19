import Vue from 'vue';
import { convertObjectPropsToCamelCase } from '~/lib/utils/common_utils';
import EnvironmentsDetailHeader from './components/environments_detail_header.vue';
import environmentsMixin from './mixins/environments_mixin';

export const initHeader = () => {
  const el = document.getElementById('environments-detail-view-header');
  const container = document.getElementById('environments-detail-view');
  const dataset = convertObjectPropsToCamelCase(JSON.parse(container.dataset.details));

  return new Vue({
    el,
    mixins: [environmentsMixin],
    data() {
      const environment = {
        name: dataset.name,
        id: Number(dataset.id),
        externalUrl: dataset.externalUrl,
        isAvailable: dataset.isEnvironmentAvailable,
        hasTerminals: dataset.hasTerminals,
        autoStopAt: dataset.autoStopAt,
        onSingleEnvironmentPage: true,
        // TODO: These two props are snake_case because the environments_mixin file uses
        // them and the mixin is imported in several files. It would be nice to conver them to camelCase.
        stop_path: dataset.environmentStopPath,
        delete_path: dataset.environmentDeletePath,
      };

      return {
        environment,
      };
    },
    render(createElement) {
      return createElement(EnvironmentsDetailHeader, {
        props: {
          environment: this.environment,
          canDestroyEnvironment: dataset.canDestroyEnvironment,
          canUpdateEnvironment: dataset.canUpdateEnvironment,
          canReadEnvironment: dataset.canReadEnvironment,
          canStopEnvironment: dataset.canStopEnvironment,
          canAdminEnvironment: dataset.canAdminEnvironment,
          cancelAutoStopPath: dataset.environmentCancelAutoStopPath,
          terminalPath: dataset.environmentTerminalPath,
          metricsPath: dataset.environmentMetricsPath,
          updatePath: dataset.environmentEditPath,
        },
      });
    },
  });
};
