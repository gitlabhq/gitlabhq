import { stateToComponentMap, statesToShowHelpWidget } from '../dependencies';

export default function baseComputed() {
  return {
    componentName() {
      return stateToComponentMap[this.mr.state];
    },
    shouldRenderMergeHelp() {
      return statesToShowHelpWidget.indexOf(this.mr.state) > -1;
    },
    shouldRenderPipelines() {
      return Object.keys(this.mr.pipeline).length || this.mr.hasCI;
    },
    shouldRenderRelatedLinks() {
      return this.mr.relatedLinks;
    },
    shouldRenderDeployments() {
      return this.mr.deployments.length;
    },
  };
}
