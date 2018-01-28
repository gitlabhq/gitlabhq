import { bisectDate } from '../utils/date_time_formatters';

const mixins = {
  methods: {
    mouseOverDeployInfo(mouseXPos) {
      if (!this.reducedDeploymentData) return false;

      let dataFound = false;
      this.reducedDeploymentData = this.reducedDeploymentData.map((d) => {
        const deployment = d;
        if (d.xPos >= mouseXPos - 10 && d.xPos <= mouseXPos + 10 && !dataFound) {
          dataFound = d.xPos + 1;

          deployment.showDeploymentFlag = true;
        } else {
          deployment.showDeploymentFlag = false;
        }
        return deployment;
      });

      return dataFound;
    },

    formatDeployments() {
      this.reducedDeploymentData = this.deploymentData.reduce((deploymentDataArray, deployment) => {
        const time = new Date(deployment.created_at);
        const xPos = Math.floor(this.timeSeries[0].timeSeriesScaleX(time));

        time.setSeconds(this.timeSeries[0].values[0].time.getSeconds());

        if (xPos >= 0) {
          const seriesIndex = bisectDate(this.timeSeries[0].values, time, 1);

          deploymentDataArray.push({
            id: deployment.id,
            time,
            sha: deployment.sha,
            commitUrl: `${this.projectPath}/commit/${deployment.sha}`,
            tag: deployment.tag,
            tagUrl: deployment.tag ? `${this.tagsPath}/${deployment.ref.name}` : null,
            ref: deployment.ref.name,
            xPos,
            seriesIndex,
            showDeploymentFlag: false,
          });
        }

        return deploymentDataArray;
      }, []);
    },

    positionFlag() {
      const timeSeries = this.timeSeries[0];
      const hoveredDataIndex = bisectDate(timeSeries.values, this.hoverData.hoveredDate, 1);
      this.currentData = timeSeries.values[hoveredDataIndex];
      this.currentDataIndex = hoveredDataIndex;
      this.currentXCoordinate = Math.floor(timeSeries.timeSeriesScaleX(this.currentData.time));
      if (this.currentXCoordinate > (this.graphWidth - 200)) {
        this.currentFlagPosition = this.currentXCoordinate - 103;
      } else {
        this.currentFlagPosition = this.currentXCoordinate;
      }

      if (this.hoverData.currentDeployXPos) {
        this.showFlag = false;
      } else {
        this.showFlag = true;
      }
    },
  },
};

export default mixins;
