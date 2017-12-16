module WebpushHelper
  def vapid_credentials
    {
      subject: "mailto:lbennett@gitlab.com",
      public_key: "BMV-YKtRZpthj5tS1sW4BBaNEqZ67gAQYH_lFLR156QD1pi4TJGZGw46rCBFbFoqV2cMNI6ilD9PZ3DPPt2nEdI",
      private_key: "3Ex0EQD-67zli0YM4SioxmYxbYvyiT1aRCTLZombOy4"
    }
  end
end
