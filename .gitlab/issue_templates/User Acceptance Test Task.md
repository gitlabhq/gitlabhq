# Test case name: TC-XX-## <!-- Example: TC-MH-1 -->

## Test case scenario

_Describe the test scenario this task corresponds to_

<!-- Example: New customer buys new SaaS Premium subscription via CDot between April 3, 2023 and April 2, 2024. -->

<table>
  <tr>
    <th>Deal Type (select everything that applies)</th>
    <th>Product Type (select everything that applies)</th>
    <th>Product Tier</th>
    <th>Deal Term (months)</th>
    <th>Ramped segments</th>
    <th>Initial Purchase Discounted?</th>
    <th>Purchase Method</th>
    <th>Purchase Path</th>
  </tr>
  <tr>
    <td>
      <ul>
        <li>- [ ] New</li>
        <li>- [ ] Add-on (Storage, CI minutes)</li>
        <li>- [ ] Add seats</li>
        <li>- [ ] Manual renewal</li>
        <li>- [ ] Auto-renewal</li>
        <li>- [ ] Upgrade</li>
        <li>- [ ] Cancellation</li>
        <li>- [ ] First order</li>
      </ul>
    </td>
    <td>
      <ul>
        <li>- [ ] SaaS</li>
        <li>- [ ] Self-managed</li>
        <li>- [ ] True-up</li>
        <li>- [ ] Add-on (Storage, CI minutes)</li>
        <li>- [ ] Extra seats</li>
        <li>- [ ] Professional services only</li>
      </ul>
    </td>
    <td>
      <ul>
        <li>- [ ] Premium</li>
        <li>- [ ] Ultimate</li>
        <li>- [ ] Premium > Ultimate (upgrade)</li>
        <li>- [ ] Legacy Premium</li>
        <li>- [ ] Legacy Ultimate</li>
      </ul>
    </td>
    <td>
      <ul>
        <li>- [ ] 12</li>
        <li>- [ ] 24</li>
        <li>- [ ] 36</li>
      </ul>
    </td>
    <td>
      <ul>
        <li>- [ ] Non-Ramp</li>
        <li>- [ ] 2</li>
        <li>- [ ] 3</li>
      </ul>
    </td>
    <td>
      <ul>
        <li>- [ ] Yes</li>
        <li>- [ ] No</li>
      </ul>
    </td>
    <td>
      <ul>
        <li>- [ ] Web store</li>
        <li>- [ ] Sales-assisted</li>
        <li>- [ ] Automated</li>
      </ul>
    </td>
    <td>
      <ul>
        <li>- [ ] Direct</li>
        <li>- [ ] Partner</li>
      </ul>
    </td>
  </tr>
</table>

## Artifacts

_Add various artifacts for this test scenario for reference_

1. Account (SFDC):
1. Opportunity (SFDC):
1. Quote (SFDC):
1. Order form (SFDC):
1. Subscription (Zuora):
1. Test case dependency (if any):

## Test steps

_List the steps to be performed to verify this scenario_

<!-- Example:

1. **GitLab.com:**: Purchase a subscription for a group
2. **CustomersDot:** Visit Customers Portal at http://customers.staging.gitlab.com
3. **CustomersDot:** Verify subscription details for purchased subscription

-->

## Expected result

_Describe the expected outcome of this test scenario_

### Screenshots

| Step | Screenshot |
|---|---|
|  |  |

<!--

You might want to create a comment or a separate issue for each of the following items, to ensure sign-off from all departments:

- [ ] Deal Desk sign-off
- [ ] Billing sign-off
- [ ] Revenue sign-off
- [ ] Fulfillment sign-off
- [ ] Data sign-off

-->

/confidential
/label ~"devops::fulfillment" ~"section::fulfillment"

<!--

You might also want to add some of the following labels, or weight:

/label ~workflow::
/label ~estimation::
/label ~group::
/label ~Category:
/label ~maintenance::
/weight

-->
