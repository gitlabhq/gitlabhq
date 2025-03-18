<!--The purpose of this issue template is to ensure that Product Designers have all the information they need BEFORE starting design (workflow::ready for design). Product Designers should collaborate with the team members requesting design work to ensure the request is fully thought through and that all necessary details to meet users' needs are included.

For example:

- Who's the user? 
- What are they trying to accomplish?
- Why do they need this?, etc.-->

## Problem and scope

<!--To be filled out by designer in collaboration with requestor (if different from team counterparts), PM and Engineering counterparts-->

<details>
<summary>See details</summary>

### What is the problem to solve?

`{ Add a brief description about the problem to solve for }`

### Who is the design solution for?

`{ Add persona and/or job performer }`

### What is the [Job](https://handbook.gitlab.com/handbook/product/ux/jobs-to-be-done/#main-job-what-is-the-job-performer-trying-to-get-done) this user is trying to achieve?

- ...

### What [outcomes](https://handbook.gitlab.com/handbook/product/ux/jobs-to-be-done/outcome-driven-innovation-pilot/topics-and-definitions/#outcomes) is this design solution helping them achieve?

If you have measured Outcome data, put that in the table. If not, delete the table and add the Outcomes to be designed for in a bulleted list.

| Outcome Statement | Importance | Satisfaction | Overall Score |
|-------------------|------------|--------------|---------------|
| `{ e.g. Minimize the time it takes for users to navigate to the desired section of the application. }` | `5` | `1` | `9` |


### What are the requirements necessary to solve for this problem and Outcomes?

`{ Create a bulleted list of everything that will need to be addressed in the holistic Design Vision in order to fully solve for the problem and Outcomes. Work with your counterparts to define this list. Keep it solution agnostic and try to understand any technical constraints that each requirement may imply. Only remove a requirement due to a technical constraint if it's not technically feasible to build within a reasonable amount of time (1-3 milestones is reasonable, anything longer than that you'll have to decide as a team how important it is to keep it in scope or address it in parallel in later iterations). }`

* ...
* ...
* ...

### What supporting research or customer validation do we have?

- `{ Add links to any supporting research and related problem validation issues }`

### What is the timeline?

`{ Add milestone or link to planning issue that clarifies when the design must be ready for the Build phase by }`

### What are the technical constraints?

`{ `:warning:` This is to understand initial constraints in which the design solution needs to work within, NOT whether the solution can be implemented in a given milestone.`

``Once the Product Designer has come up with a holistic Design Vision, or an ideal state for solving the problem, they should collaborate with their team members and engineers to continue the technical feasibility discussion during ``~"workflow::planning breakdown"``. }``

- `{ e.g. All visualization must use [eCharts](https://echarts.apache.org/examples/en/index.html#chart-type-line) }`
- `{ e.g. Data prior to 2024-10-10 will not be available }`
- `{ e.g. Solution will only be visible to Maintainer roles }`

### In what parts of GitLab will this solution be available?

Plans:

* [ ] Free
* [ ] Premium
* [ ] Ultimate

Instances:

* [ ] Self-managed
* [ ] Dedicated
* [ ] GitLab.com

Levels:

* [ ] Instance
* [ ] Group
* [ ] Project

### How will we know if the solution is successful?

`{ If you don't have measured Outcome data to measure against, what other success metrics can we use? Otherwise you can reference the Outcomes table above (your goal is to beat the previous Outcome measurements Satisfaction numbers with this new design). }`

</details>

## Ready for design

<details>
<summary>See checklist</summary>

<!--*** Note for Product Designer:
- Do not begin designing until you are confident you have everything you need to begin designing.
- Do not default to designing a small MVC first. Instead, think about the ideal solution / holistic Design Vision first.-->

* [ ] The problem has been defined and is well understood
* [ ] Who the design solution is for has been defined
* [ ] User goals and outcomes have been defined
* [ ] Supporting research has been reviewed and linked
* [ ] The product requirements have been defined, and the scope has been agreed upon
* [ ] Success metrics have been defined and agreed upon
* [ ] I, as the Product Designer, believe I have all the information I need to begin creating a design solution
* [ ] Move this issue to \~"workflow::ready for design" or ~"workflow::design" :tada:
* [ ] (Optional) Help improve this issue template, [view feedback issue](https://gitlab.com/gitlab-org/gitlab/-/issues/519682) 

</details>

## Proposal

<details>
<summary>See checklist reminder</summary>

* [ ] Follow the [Product design process](https://handbook.gitlab.com/handbook/product/ux/product-designer/#ideate-and-iterate)
* [ ] [Start with a long-term vision](https://handbook.gitlab.com/handbook/values/#start-with-a-long-term-vision)
* [ ] Remember to link your video walkthrough, prototypes, Figma project

</details>

- :tv: Walkthrough
- :frame_photo: Design Solution Proposal
- ❖ Figma project →

## Design breakdown

Once the proposal is agreed upon, work with your team to break it down into buildable parts (MVC, Iteration 1, Iteration 2, etc... until fully built).

<details>
<summary>See checklist</summary>

* [ ] Design Vision broken down into MVC and follow-up iterations based on their ability to stand alone and provide value to the user
* [ ] Create MVC and other necessary Iteration 1, Iteration 2... issues and add them as Linked items to this issue
  * [ ] Include all necessary requirements, and specs needed to create the designs for each broken down issue

</details>

/label ~"UX" ~"UX Template Applied" ~"workflow::start"