/* eslint-disable no-param-reassign */

const mixins = {
  methods: {
    mouseOverDeployInfo(mouseXPos) {
      if (!this.reducedDeploymentData) return false;

      let dataFound = false;
      this.reducedDeploymentData.forEach((d) => {
        if (d.xPos >= mouseXPos - 10 && d.xPos <= mouseXPos + 10 && !dataFound) {
          dataFound = d.xPos + 1;

          d.showDeploymentFlag = true;
        } else {
          d.showDeploymentFlag = false;
        }
      });

      return dataFound;
    },
    formatDeployments() {
      this.reducedDeploymentData = this.deploymentData.reduce((deploymentDataArray, deployment) => {
        const time = new Date(deployment.created_at);
        const xPos = Math.floor(this.xScale(time));

        time.setSeconds(this.data[0].time.getSeconds());

        if (xPos >= 0) {
          deploymentDataArray.push({
            id: deployment.id,
            time,
            sha: deployment.sha,
            tag: deployment.tag,
            ref: deployment.ref.name,
            xPos,
            showDeploymentFlag: false,
          });
        }

        return deploymentDataArray;
      }, []);
    },
  },
};

export default mixins;
